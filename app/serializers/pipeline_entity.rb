class PipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :user, using: UserEntity

  expose :path do |pipeline|
    namespace_project_pipeline_path(
      pipeline.project.namespace,
      pipeline.project,
      pipeline)
  end

  expose :details do
    expose :status do |pipeline, options|
      StatusEntity.represent(
        pipeline.detailed_status(request.user),
        options)
    end

    expose :duration
    expose :finished_at
    expose :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
  end

  expose :flags do
    expose :latest?, as: :latest
    expose :triggered?, as: :triggered
    expose :stuck?, as: :stuck
    expose :has_yaml_errors?, as: :yaml_errors
    expose :can_retry?, as: :retryable
    expose :can_cancel?, as: :cancelable
  end

  expose :ref do
    expose :name do |pipeline|
      pipeline.ref
    end

    expose :path do |pipeline|
      namespace_project_tree_path(
        pipeline.project.namespace,
        pipeline.project,
        id: pipeline.ref)
    end

    expose :tag?, as: :tag
    expose :branch?, as: :branch
  end

  expose :commit, using: CommitEntity
  expose :yaml_errors, if: ->(pipeline, _) { pipeline.has_yaml_errors? }

  expose :retry_path, if: proc { can_retry? }  do |pipeline|
    retry_namespace_project_pipeline_path(pipeline.project.namespace,
                                          pipeline.project,
                                          pipeline.id)
  end

  expose :cancel_path, if: proc { can_cancel? } do |pipeline|
    cancel_namespace_project_pipeline_path(pipeline.project.namespace,
                                           pipeline.project,
                                           pipeline.id)
  end

  expose :created_at, :updated_at

  private

  alias_method :pipeline, :object

  def can_retry?
    pipeline.retryable? &&
      can?(request.user, :update_pipeline, pipeline)
  end

  def can_cancel?
    pipeline.cancelable? &&
      can?(request.user, :update_pipeline, pipeline)
  end
end
